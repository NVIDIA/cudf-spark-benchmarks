WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier AS s
    JOIN partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_price
    FROM customer AS c
    LEFT JOIN orders AS o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation AS n
    JOIN supplier AS s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem AS l ON ps.ps_partkey = l.l_partkey
    GROUP BY n.n_nationkey, n.n_name
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders AS o
    WHERE o.o_orderstatus IN ('O', 'F') AND o.o_totalprice IS NOT NULL
),
SupplierCustomerAnalysis AS (
    SELECT 
        cs.c_custkey,
        cs.order_count,
        ns.total_sales,
        rs.total_cost,
        COALESCE(rs.total_cost / NULLIF(cs.order_count, 0), 0) AS cost_per_order
    FROM CustomerOrderStats AS cs
    LEFT JOIN NationSales AS ns ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation AS n WHERE n.n_name = 'UNITED STATES')  
    LEFT JOIN RankedSuppliers AS rs ON cs.c_custkey = rs.s_suppkey
    WHERE cs.order_count > 0
)
SELECT 
    f.o_orderkey,
    f.o_totalprice,
    f.order_rank,
    COALESCE(sa.cost_per_order, 0) AS avg_cost_per_order,
    ns.total_sales AS nation_sales,
    CASE 
        WHEN ns.total_sales < 500000 THEN 'Low Sales'
        WHEN ns.total_sales BETWEEN 500000 AND 1000000 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM FilteredOrders AS f
LEFT JOIN SupplierCustomerAnalysis AS sa ON f.o_orderkey = sa.c_custkey
LEFT JOIN NationSales AS ns ON ns.n_name = 'UNITED STATES'  
WHERE f.order_rank <= 10
ORDER BY f.o_totalprice DESC, f.o_orderkey ASC;