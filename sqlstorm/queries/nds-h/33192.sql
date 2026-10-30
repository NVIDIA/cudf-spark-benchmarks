WITH  SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
), SupplierAgg AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
), NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(scte.total_sales), 0) AS nation_sales,
        sa.total_supplycost,
        COALESCE(SUM(scte.total_sales) / NULLIF(sa.total_supplycost, 0), 0) AS sales_to_supply_ratio
    FROM nation n
    LEFT JOIN SalesCTE scte ON n.n_nationkey = scte.c_custkey
    LEFT JOIN SupplierAgg sa ON n.n_nationkey = sa.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, sa.total_supplycost
)
SELECT 
    ns.n_nationkey,
    ns.n_name,
    ns.nation_sales,
    ns.total_supplycost,
    ns.sales_to_supply_ratio,
    CASE 
        WHEN ns.sales_to_supply_ratio > 1 THEN 'High Efficiency'
        WHEN ns.sales_to_supply_ratio BETWEEN 0.5 AND 1 THEN 'Moderate Efficiency'
        ELSE 'Low Efficiency' 
    END AS efficiency_category,
    ROW_NUMBER() OVER (ORDER BY ns.nation_sales DESC) AS rank_within_nations,
    CONCAT(ns.n_name, ' - Sales Efficiency: ', 
        CASE 
            WHEN ns.sales_to_supply_ratio > 1 THEN 'Excellent'
            WHEN ns.sales_to_supply_ratio BETWEEN 0.5 AND 1 THEN 'Good'
            ELSE 'Needs Improvement' 
        END) AS detailed_comment
FROM NationSales ns
WHERE ns.nation_sales > 0 OR ns.total_supplycost > 0
ORDER BY ns.nation_sales DESC;
