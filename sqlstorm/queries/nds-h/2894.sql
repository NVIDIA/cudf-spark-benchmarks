WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),

TopPartSupp AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),

HighValueCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.order_count,
        cust.total_spent
    FROM CustomerOrders cust
    WHERE cust.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),

SupplierDetails AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        tp.total_available
    FROM RankedSuppliers rs
    JOIN TopPartSupp tp ON rs.s_suppkey = tp.ps_partkey
    WHERE rs.supplier_rank = 1
)

SELECT 
    NF.n_name AS nation_name,
    COALESCE(SD.s_name, 'No Suppliers') AS supplier_name,
    COALESCE(CUST.total_spent, 0) AS total_spent,
    COALESCE(CUST.order_count, 0) AS order_count,
    SUM(LI.l_extendedprice * (1 - LI.l_discount)) AS total_revenue
FROM nation NF
LEFT JOIN supplier S ON NF.n_nationkey = S.s_nationkey
LEFT JOIN SupplierDetails SD ON S.s_suppkey = SD.s_suppkey
LEFT JOIN lineitem LI ON SD.s_suppkey = LI.l_suppkey
LEFT JOIN HighValueCustomers CUST ON CUST.c_custkey = LI.l_orderkey
WHERE LI.l_shipdate >= DATE '1997-01-01'
    AND (SD.s_acctbal IS NULL OR SD.s_acctbal > 100.00)
GROUP BY NF.n_name, SD.s_name, CUST.total_spent, CUST.order_count
ORDER BY total_revenue DESC;