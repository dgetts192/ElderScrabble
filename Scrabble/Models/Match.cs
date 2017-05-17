using System;
using System.Collections.Generic;

namespace Scrabble.Models
{
    public partial class Match
    {
        public int Id { get; set; }
        public int PlayerOneId { get; set; }
        public int PlayerTwoId { get; set; }
        public int LocationId { get; set; }
        public int PlayerOneScore { get; set; }
        public int PlayerTwoScore { get; set; }
        public DateTime DatePlayed { get; set; }

        public virtual Location Location { get; set; }
        public virtual Member PlayerOne { get; set; }
        public virtual Member PlayerTwo { get; set; }
    }
}
