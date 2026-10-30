WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
        JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
FinalReport AS (
    SELECT 
        h.c_name AS customer_name,
        hs.s_name AS supplier_name,
        os.total_revenue,
        os.o_orderdate,
        os.o_orderstatus
    FROM 
        HighValueCustomers h
        LEFT JOIN RankedSuppliers hs ON h.c_custkey = hs.s_suppkey
        JOIN OrderSummary os ON os.o_orderkey = h.c_custkey
    WHERE 
        os.total_revenue > 10000 AND 
        hs.supplier_rank <= 5
)
SELECT 
    f.customer_name,
    f.supplier_name,
    f.total_revenue,
    f.o_orderdate,
    f.o_orderstatus
FROM 
    FinalReport f
ORDER BY 
    f.total_revenue DESC
LIMIT 50;
