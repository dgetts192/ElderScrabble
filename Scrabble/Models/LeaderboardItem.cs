using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Scrabble.Models
{
    public class LeaderboardItem
    {   
        public int PlayerId { get; set; }
        public string PlayerName { get; set; }
        public int AverageScore { get; set; }
    }
}
