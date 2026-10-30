WITH RankedLineItems AS (
    SELECT 
        l_orderkey,
        l_partkey,
        l_suppkey,
        l_linenumber,
        l_quantity,
        l_extendedprice,
        l_discount,
        l_tax,
        l_returnflag,
        l_linestatus,
        l_shipdate,
        DENSE_RANK() OVER (PARTITION BY l_orderkey ORDER BY l_extendedprice DESC) AS rank_per_order,
        CASE 
            WHEN l_discount > 0.05 THEN l_extendedprice * (1 - l_discount) 
            ELSE l_extendedprice 
        END AS adjusted_price
    FROM lineitem
    WHERE l_shipdate BETWEEN '1995-01-01' AND '1996-12-31'
),
TotalSales AS (
    SELECT 
        o.o_orderkey,
        SUM(rl.adjusted_price * rl.l_quantity) AS total_sales,
        COUNT(DISTINCT rl.l_partkey) AS unique_parts
    FROM orders o
    JOIN RankedLineItems rl ON o.o_orderkey = rl.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_orderkey
    HAVING COUNT(DISTINCT rl.l_partkey) > 5
),
SupplierDetail AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * rl.l_quantity) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN RankedLineItems rl ON ps.ps_partkey = rl.l_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT 
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    SUM(ts.total_sales) AS total_order_sales,
    COUNT(DISTINCT sd.s_suppkey) AS suppliers_count,
    AVG(sd.total_supply_cost) AS average_supply_cost,
    RANK() OVER (ORDER BY SUM(ts.total_sales) DESC) AS sales_rank
FROM TotalSales ts
LEFT JOIN customer c ON ts.o_orderkey = c.c_custkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN SupplierDetail sd ON n.n_nationkey = sd.s_suppkey
GROUP BY n.n_name
HAVING AVG(sd.total_supply_cost) IS NOT NULL
   AND COUNT(DISTINCT ts.o_orderkey) > 10
UNION ALL
SELECT 
    'Total' AS nation_name,
    SUM(ts.total_sales) AS total_order_sales,
    COUNT(DISTINCT sd.s_suppkey) AS suppliers_count,
    AVG(sd.total_supply_cost) AS average_supply_cost,
    NULL AS sales_rank
FROM TotalSales ts
JOIN SupplierDetail sd ON ts.o_orderkey = sd.s_suppkey
WHERE sd.s_acctbal IS NOT NULL
ORDER BY total_order_sales DESC;
