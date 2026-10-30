WITH SupplierSales AS (
    SELECT 
        s.s_name,
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_name, n.n_name
),
NationSummary AS (
    SELECT 
        nation, 
        SUM(total_sales) AS nation_sales,
        SUM(total_orders) AS nation_order_count
    FROM SupplierSales
    GROUP BY nation
),
TopNations AS (
    SELECT 
        nation, 
        nation_sales, 
        nation_order_count,
        RANK() OVER (ORDER BY nation_sales DESC) AS sales_rank
    FROM NationSummary
)
SELECT 
    nation,
    nation_sales,
    nation_order_count
FROM TopNations
WHERE sales_rank <= 5
ORDER BY nation_sales DESC;
