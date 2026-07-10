using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VeterinerAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddClinicReviewConstraints : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "updated_at",
                table: "clinic_reviews",
                type: "datetime(6)",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_clinic_reviews_clinic_id_user_id",
                table: "clinic_reviews",
                columns: new[] { "clinic_id", "user_id" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_clinic_reviews_clinic_id_user_id",
                table: "clinic_reviews");

            migrationBuilder.DropColumn(
                name: "updated_at",
                table: "clinic_reviews");
        }
    }
}
