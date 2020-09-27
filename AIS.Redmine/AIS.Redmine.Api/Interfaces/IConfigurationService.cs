using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AIS.Redmine.Api.Models
{
    public interface IConfigurationService
    {
        public string Get(string paramName);
        public DateTimeOffset? GetDateTimeOffset(string paramName);

        public Task<bool> SetAndSaveAsync(string paramName, string value);
        public Task<bool> SetAndSaveAsync(string paramName, DateTimeOffset? value);

        public void Reset();
    }
}
