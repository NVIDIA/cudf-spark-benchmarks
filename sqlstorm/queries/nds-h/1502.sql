WITH RegionalSales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderdate >= DATE '1995-01-01' 
        AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY
        r.r_name
),
TopRegions AS (
    SELECT
        region_name,
        total_sales,
        order_count,
        total_quantity
    FROM
        RegionalSales
    WHERE
        rank_sales <= 5
),
SupplierInfo AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(NULLIF(SUM(ps.ps_supplycost), 0), 0) AS total_supplycost
    FROM
        supplier s
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT
    t.region_name,
    t.total_sales,
    t.order_count,
    t.total_quantity,
    s.s_name,
    s.total_supplycost,
    CASE 
        WHEN s.s_acctbal >= t.total_sales THEN 'High'
        WHEN s.s_acctbal < t.total_sales AND s.total_supplycost > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS supplier_rating
FROM
    TopRegions t
LEFT JOIN
    SupplierInfo s ON s.total_supplycost > (SELECT AVG(total_supplycost) FROM SupplierInfo)
ORDER BY
    t.total_sales DESC, s.total_supplycost ASC;