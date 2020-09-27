using Microsoft.CodeAnalysis.CSharp.Syntax;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace AIS.Redmine.Api
{
    public static class XmlExtensions
    {
        public static string ToStringWithoutDeclaration(this XDocument xDoc)
        {
            // reset declaration
            xDoc.Declaration = null;

            return xDoc.ToString(SaveOptions.DisableFormatting);
        }

        public static int GetTotalCount(this XDocument xDoc)
        {
            int result = 0;

            var attr = xDoc.Root.Attribute("total_count");

            if (attr != null)
                int.TryParse(attr.Value, out result);

            return result;
        }

        public static int GetElementsCount(this XDocument xDoc)
        {
            return xDoc.Root.Elements().Count();
        }

    }
}
