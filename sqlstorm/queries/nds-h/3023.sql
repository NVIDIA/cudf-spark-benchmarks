WITH SupplierSales AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    ns.n_name AS nation,
    COUNT(DISTINCT ss.s_name) AS supplier_count,
    SUM(cs.total_spent) AS total_customer_spending,
    MAX(ss.total_sales) AS max_supplier_sales
FROM region r
JOIN nation ns ON ns.n_regionkey = r.r_regionkey
LEFT JOIN SupplierSales ss ON ss.s_acctbal > 50000 AND ss.sales_rank = 1
LEFT JOIN CustomerOrders cs ON cs.order_count > 5
GROUP BY r.r_name, ns.n_name
HAVING SUM(cs.total_spent) IS NOT NULL
ORDER BY r.r_name, nation;
