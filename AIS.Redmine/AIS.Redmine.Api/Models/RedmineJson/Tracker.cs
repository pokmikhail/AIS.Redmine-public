using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace AIS.Redmine.Api.Models.RedmineJson
{
    public class TrackerResponse
    {
        [JsonPropertyName("trackers")]
        public List<Tracker> TrackersList { get; set; }
    }

    public class Tracker
    {
        public int Id { get; set; }
        public string Name { get; set; }

        //[JsonPropertyName("default_status")]
        //public IssueStatus DefaultStatus { get; set; }
    }
}
