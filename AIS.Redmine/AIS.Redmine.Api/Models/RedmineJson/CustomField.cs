using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace AIS.Redmine.Api.Models.RedmineJson
{
    public class CustomFieldResponse
    {
        [JsonPropertyName("custom_fields")]
        public List<CustomField> FieldList { get; set; }
    }

    public class CustomField
    {
        public int Id { get; set; }
        public string Name { get; set; }
        [JsonPropertyName("customized_type")]
        public string Type { get; set; }
        [JsonPropertyName("field_format")]
        public string Format { get; set; }
        
        //public string RegExp { get; set; }
        //[JsonPropertyName("min_length")]
        //public int MinLength { get; set; }
        //[JsonPropertyName("max_length")]
        //public int MaxLength { get; set; }

        [JsonPropertyName("is_required")]
        public bool IsRequired { get; set; }

        //[JsonPropertyName("is_filter")]
        //public bool IsFilter { get; set; }
        //[JsonPropertyName("searchable")]
        //public bool IsSearchable { get; set; }
        
        [JsonPropertyName("multiple")]
        public bool IsMultiple { get; set; }
        
        //[JsonPropertyName("default_value")]
        //public string DefaultValue { get; set; }
        //[JsonPropertyName("visible")]
        //public bool IsVisible { get; set; }
        //public List Trackers { get; set; }
        //public List Roles { get; set; }
    }
}
