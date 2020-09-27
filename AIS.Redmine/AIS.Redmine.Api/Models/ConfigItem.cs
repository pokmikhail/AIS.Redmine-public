using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AIS.Redmine.Api.Models
{
    public class ConfigItem
    {
        public string Code { get; set; }
        public string Name { get; set; }
        public string Desctription { get; set; }
        public string Value { get; set; }
    }
}
