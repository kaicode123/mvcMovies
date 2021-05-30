using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace CoreWebAppSimple
{
    public class Program
    {
        public static void Main(string[] args)
        {
            BuildWebHost(args).Run();
        }

        public static IWebHost BuildWebHost(string[] args) =>
            WebHost.CreateDefaultBuilder(args)
            // - Kai edit, just added line below:
           //     .UseUrls("http://10.10.100.4:5000")
                 .UseUrls("http://0.0.0.0:5000")
            // - end edit. 
                .UseStartup<Startup>()
                .Build();
    }
}
