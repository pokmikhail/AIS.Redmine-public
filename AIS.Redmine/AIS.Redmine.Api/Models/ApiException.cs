using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AIS.Redmine.Api.Models
{
    public class ApiException : Exception
    {
        public ApiException(string message)
            : base(message)
        { }
    }
}
