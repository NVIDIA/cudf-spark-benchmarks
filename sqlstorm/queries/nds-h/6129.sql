
WITH TotalRevenue AS (
    SELECT
        n.n_name AS Nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY
        n.n_name
),
SupplierCount AS (
    SELECT
        p.p_partkey,
        COUNT(DISTINCT s.s_suppkey) AS SuppCount
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        p.p_partkey
),
HighRevenueRegions AS (
    SELECT
        tr.Nation,
        tr.Revenue,
        CASE 
            WHEN tr.Revenue > 1000000 THEN 'High'
            WHEN tr.Revenue BETWEEN 500000 AND 1000000 THEN 'Medium'
            ELSE 'Low'
        END AS RevenueCategory
    FROM
        TotalRevenue tr
)
SELECT
    hr.Nation,
    hr.Revenue,
    hr.RevenueCategory,
    COUNT(DISTINCT sc.p_partkey) AS UniquePartsSupplied,
    SUM(sc.SuppCount) AS TotalSuppliers
FROM
    HighRevenueRegions hr
LEFT JOIN
    SupplierCount sc ON hr.Nation = (
        SELECT n.n_name
        FROM nation n
        JOIN customer c ON n.n_nationkey = c.c_nationkey
        JOIN orders o ON c.c_custkey = o.o_custkey
        WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
        LIMIT 1
    )
GROUP BY
    hr.Nation, hr.Revenue, hr.RevenueCategory
ORDER BY
    hr.Revenue DESC;
