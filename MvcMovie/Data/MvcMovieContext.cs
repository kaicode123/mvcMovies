using Microsoft.EntityFrameworkCore;
using MvcMovie.Models;

namespace MvcMovie.Data
{
    public class MvcMovieContext : DbContext
    {
        public MvcMovieContext(DbContextOptions options)
            : base(options)
        {
        }

        public DbSet <Movies> Movies { get; set; }
    }
}
