WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY l.l_suppkey
),
ActiveCustomers AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    GROUP BY c.c_custkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        COALESCE(ts.total_revenue, 0) AS total_revenue,
        COALESCE(rs.rn, 0) AS supplier_rank
    FROM supplier s
    LEFT JOIN TotalSales ts ON s.s_suppkey = ts.l_suppkey
    LEFT JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
)
SELECT 
    sd.s_name,
    sd.s_address,
    sd.total_revenue,
    sd.supplier_rank,
    ac.order_count
FROM SupplierDetails sd
LEFT JOIN ActiveCustomers ac ON sd.s_suppkey = ac.c_custkey
WHERE (sd.total_revenue > 10000 OR sd.supplier_rank <= 5)
ORDER BY sd.total_revenue DESC, sd.supplier_rank ASC
LIMIT 10;