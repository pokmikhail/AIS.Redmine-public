using AIS.Redmine.Api.Models;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace AIS.Redmine.Api.Services
{
    public class RedmineXmlImporter
    {
        private readonly IServiceProvider _services;

        public RedmineXmlImporter(IServiceProvider services)
        {
            _services = services;
        }

        /// <summary>
        /// Reads an xml response from Redmine API
        /// </summary>
        /// <param name="uri">Uri to work with. If pageSize > 0, &amp;offset and &amp;limit will be added to uri</param>
        /// <param name="page">Page number to receive. Used to calculate "offset" argument for Redmine paged methods</param>
        /// <param name="pageSize">Passed as "limit" argument for Redmine paged methods</param>
        /// <returns>Response string</returns>
        public async static Task<XDocument> ReceiveXmlAsync(string uri, int page, int pageSize)
        {
            using var client = CreateWebClient();

            if (pageSize > 0)
                uri += $"&offset={page * pageSize}&limit={pageSize}";

            var xml = await client.DownloadStringTaskAsync(new Uri(uri));

            return XDocument.Parse(xml);
        }

        /// <summary>
        /// Created WebClient to work with Redmine API
        /// </summary>
        /// <returns></returns>
        public static WebClient CreateWebClient()
        {
            return new WebClient
            {
                Encoding = System.Text.Encoding.UTF8
            };
        }

        public async static Task<List<int>> GetPageList(string uri, int limit)
        {
            if (limit <= 0)
                throw new ArgumentOutOfRangeException(nameof(limit));

            var xDoc = await ReceiveXmlAsync(uri, 0, 1);

            var page = 0;
            var total = xDoc.GetTotalCount();

            var result = new List<int>();
            while (page * limit < total)
            {
                result.Add(page);
                page++;
            }

            return result;
        }

        /// <summary>
        /// Processes one page of user data
        /// </summary>
        /// <param name="xDoc">Xml from Redmine REST /users.xml</param>
        /// <param name="isActive">response status field. If 1, then true, if 3, then false</param>
        /// <returns>Processsing statistics</returns>
        public async Task<ImportStats> ProcessUsersAsync(XDocument xDoc, bool isActive)
        {
            var xml = xDoc.ToStringWithoutDeclaration();

            return await _executeSql(
                "EXEC dbo.RedmineProcessUsers @xml={0}, @isActive={1}, @total={2} OUTPUT, @added={3} OUTPUT, @updated={4} OUTPUT, @deleted={5} OUTPUT",
                xml,
                isActive
                );
        }

        /// <summary>
        /// Processes one page of project data
        /// </summary>
        /// <param name="xDoc">Xml from Redmine REST /projects.xml</param>
        /// <returns>Processsing statistics</returns>
        public async Task<ImportStats> ProcessProjectsAsync(XDocument xDoc)
        {
            return await _executeProcedure("dbo.RedmineProcessProjects", xDoc);
        }

        /// <summary>
        /// Processes one page of project versions data
        /// </summary>
        /// <param name="xDoc">Xml from Redmine REST /projects/:id/versions.xml</param>
        /// <returns>Processsing statistics</returns>
        public async Task<ImportStats> ProcessVersionsAsync(XDocument xDoc)
        {
            return await _executeProcedure("dbo.RedmineProcessVersions", xDoc);
        }

        /// <summary>
        /// Processes one page of issue list data
        /// </summary>
        /// <param name="xDoc">Xml from Redmine REST /issues.xml</param>
        /// <returns>Processsing statistics</returns>
        public async Task<ImportStats> ProcessIssuesAsync(XDocument xDoc)
        {
            return await _executeProcedure("dbo.RedmineProcessIssues", xDoc);
        }

        /// <summary>
        /// Processes one page of issue list data
        /// </summary>
        /// <param name="xDoc">xml from Redmine REST /time_entries.xml</param>
        /// <returns>Processsing statistics</returns>
        public async Task<ImportStats> ProcessTimeEntriesAsync(XDocument xDoc)
        {
            return await _executeProcedure("dbo.RedmineProcessTimeEntries", xDoc);
        }

        /// <summary>
        /// Processes issue details data
        /// </summary>
        /// <param name="xDoc">Xml from Redmine REST /issue/:id.xml</param>
        /// <returns>Processsing statistics</returns>
        public async Task<ImportStats> ProcessIssueDetailsAsync(XDocument xDoc)
        {
            return await _executeProcedure("dbo.RedmineProcessIssueDetails", xDoc);
        }

        /// <summary>
        /// Executes procedure for simple processor
        /// </summary>
        /// <param name="procName">Name of stored procedure</param>
        /// <param name="xDoc">Xml to pass to procedure</param>
        /// <returns>Processsing statistics</returns>
        private async Task<ImportStats> _executeProcedure(string procName, XDocument xDoc)
        {
            var xml = xDoc.ToStringWithoutDeclaration();

            return await _executeSql(
                "EXEC " + procName + " @xml={0}, @total={1} OUTPUT, @added={2} OUTPUT, @updated={3} OUTPUT, @deleted={4} OUTPUT",
                xml
                );
        }

        /// <summary>
        /// Executes any sql to process data adding output parameters to fill result
        /// </summary>
        /// <param name="sql">SQL to execute with placeholders for @total, @added, @updated and @deleted output parameters</param>
        /// <param name="queryParams">Query parameters to add to query call, except output parameters</param>
        /// <returns></returns>
        private async Task<ImportStats> _executeSql(string sql, params object[] queryParams)
        {
            using var scope = _services.CreateScope();
            using var db = scope.ServiceProvider.GetRequiredService<DB>();

            var parameters = new List<object>(queryParams);

            var total = new SqlParameter("@total", System.Data.SqlDbType.Int);
            total.Direction = System.Data.ParameterDirection.Output;
            parameters.Add(total);

            var added = new SqlParameter("@added", System.Data.SqlDbType.Int);
            added.Direction = System.Data.ParameterDirection.Output;
            parameters.Add(added);

            var updated = new SqlParameter("@updated", System.Data.SqlDbType.Int);
            updated.Direction = System.Data.ParameterDirection.Output;
            parameters.Add(updated);

            var deleted = new SqlParameter("@deleted", System.Data.SqlDbType.Int);
            deleted.Direction = System.Data.ParameterDirection.Output;
            parameters.Add(deleted);

            await db.Database.ExecuteSqlRawAsync(sql, parameters);

            var result = new ImportStats();

            if (total.Value != DBNull.Value)
                result.total = (int) total.Value;
            if (added.Value != DBNull.Value)
                result.added = (int)added.Value;
            if (updated.Value != DBNull.Value)
                result.updated = (int)updated.Value;
            if (deleted.Value != DBNull.Value)
                result.deleted = (int)deleted.Value;

            return result;
        }
    }
}
