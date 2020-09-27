using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace AIS.Redmine.Api.Models.RedmineJson
{
    public class IssuePriorityResponse
    {
        [JsonPropertyName("issue_priorities")]
        public List<IssuePriority> PriorityList { get; set; }
    }

    public class IssuePriority
    {
        public int Id { get; set; }
        public string Name { get; set; }

        //[JsonPropertyName("is_default")]
        //public int IsDefault { get; set; }
    }
}
