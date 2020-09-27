using AIS.Redmine.Models;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AIS.Redmine.Api.Models
{
    public class ApiResponse
    {
        public bool IsSuccess { get; set; }
        public string Message { get; set; }

        public ApiResponse()
        {
            IsSuccess = true;
        }

        public ApiResponse(bool isSuccess, string message)
        {
            IsSuccess = isSuccess;
            Message = message;
        }

        public static ApiResponse<T> Create<T>(T Data)
        {
            return new ApiResponse<T>(Data);
        }
    }

    public class ApiResponse<T> : ApiResponse
    {
        public T Data { get; set; }

        public ApiResponse(T data)
            : base()
        {
            Data = data;
        }

        public ApiResponse(bool isSuccess, string message, T data)
            : base(isSuccess, message)
        {
            Data = data;
        }
    }
}
