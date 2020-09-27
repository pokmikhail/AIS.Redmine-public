using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace AIS.Redmine.Api.Models.RedmineJson
{
    public class IssueStatusResponse
    {
        [JsonPropertyName("issue_statuses")]
        public List<IssueStatus> StatusList { get; set; }
    }

    public class IssueStatus
    {
        public int Id { get; set; }
        public string Name { get; set; }

        //[JsonPropertyName("is_default")]
        //public int IsDefault { get; set; }

        [JsonPropertyName("is_closed")]
        public bool IsClosed { get; set; }
    }
}
