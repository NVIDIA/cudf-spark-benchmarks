WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty * (1 - ps.ps_supplycost / s.s_acctbal)) AS supply_value
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_name, 
        ROW_NUMBER() OVER (ORDER BY supply_value DESC) AS rn
    FROM 
        SupplierDetails s
    WHERE 
        NOT EXISTS (
            SELECT 1
            FROM partsupp ps
            WHERE ps.ps_supplycost < 0
            AND ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size < 5)
        )
    LIMIT 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        c.c_custkey
)
SELECT 
    DISTINCT
    r.r_name, 
    n.n_name, 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT co.c_custkey) AS unique_customers,
    COUNT(DISTINCT ro.o_orderkey) FILTER (WHERE ro.order_rank = 1) AS recent_orders
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = s.s_suppkey
JOIN 
    RankedOrders ro ON ro.o_custkey = co.c_custkey
WHERE 
    l.l_returnflag = 'N'
    AND (l.l_shipdate < cast('1998-10-01' as date) OR l.l_discount IS NULL)
GROUP BY 
    r.r_name, n.n_name
HAVING 
    SUM(l.l_extendedprice) > (SELECT AVG(l_extendedprice) FROM lineitem WHERE l_discount < 0.05)
ORDER BY 
    total_revenue DESC 
LIMIT 5;