WITH String_Stats AS (
    SELECT
        s.s_suppkey AS SupplierID,
        s.s_name AS SupplierName,
        COUNT(DISTINCT p.p_partkey) AS PartCount,
        SUM(ps.ps_availqty) AS TotalAvailableQuantity,
        AVG(ps.ps_supplycost) AS AverageSupplyCost,
        MAX(LENGTH(s.s_name)) AS MaxNameLength,
        MIN(LENGTH(s.s_name)) AS MinNameLength,
        SUM(CASE WHEN POSITION('premium' IN s.s_comment) > 0 THEN 1 ELSE 0 END) AS PremiumSupplierCount
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
String_Aggregates AS (
    SELECT
        SUM(MaxNameLength) AS SumOfMaxLengths,
        AVG(MinNameLength) AS AvgMinLength,
        SUM(PremiumSupplierCount) AS TotalPremiumSuppliers
    FROM
        String_Stats
)
SELECT
    ss.SupplierID,
    ss.SupplierName,
    ss.PartCount,
    ss.TotalAvailableQuantity,
    ss.AverageSupplyCost,
    sa.SumOfMaxLengths,
    sa.AvgMinLength,
    sa.TotalPremiumSuppliers
FROM
    String_Stats ss, String_Aggregates sa
WHERE
    ss.PartCount > 1
ORDER BY
    ss.AverageSupplyCost DESC, ss.TotalAvailableQuantity ASC;
