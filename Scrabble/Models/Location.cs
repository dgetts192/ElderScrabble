using System;
using System.Collections.Generic;

namespace Scrabble.Models
{
    public partial class Location
    {
        public Location()
        {
            Match = new HashSet<Match>();
        }

        public int Id { get; set; }
        public string Name { get; set; }
        public decimal? Longitude { get; set; }
        public decimal? Latitude { get; set; }

        public virtual ICollection<Match> Match { get; set; }
    }
}
