WITH RegionalSales AS (
    SELECT
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY
        n.n_name, r.r_name
),
TopNations AS (
    SELECT
        nation_name,
        region_name,
        total_sales,
        unique_customers,
        RANK() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
    FROM
        RegionalSales
),
SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
)
SELECT
    t.nation_name,
    t.region_name,
    t.total_sales,
    t.unique_customers,
    ss.s_name AS supplier_name,
    ss.supplied_parts,
    ss.total_supply_cost,
    CASE
        WHEN t.unique_customers > 1000 THEN 'High'
        WHEN t.unique_customers BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS customer_segment
FROM
    TopNations t
LEFT JOIN
    SupplierStats ss ON t.nation_name = ss.s_name
WHERE
    t.sales_rank <= 5
ORDER BY
    t.region_name, t.total_sales DESC;