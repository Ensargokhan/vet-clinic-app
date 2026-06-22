using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VeterinerAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddClinicAdmin : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "admin_user_id",
                table: "clinics",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_clinics_admin_user_id",
                table: "clinics",
                column: "admin_user_id");

            migrationBuilder.AddForeignKey(
                name: "FK_clinics_users_admin_user_id",
                table: "clinics",
                column: "admin_user_id",
                principalTable: "users",
                principalColumn: "id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_clinics_users_admin_user_id",
                table: "clinics");

            migrationBuilder.DropIndex(
                name: "IX_clinics_admin_user_id",
                table: "clinics");

            migrationBuilder.DropColumn(
                name: "admin_user_id",
                table: "clinics");
        }
    }
}
