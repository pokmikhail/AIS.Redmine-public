using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace AIS.Redmine.Api.Models.RedmineJson
{
    public class TimeEntryTypeResponse
    {
        [JsonPropertyName("time_entry_activities")]
        public List<TimeEntryType> TypeList { get; set; }
    }

    public class TimeEntryType
    {
        public int Id { get; set; }
        public string Name { get; set; }

        //[JsonPropertyName("is_default")]
        //public int IsDefault { get; set; }
    }
}
