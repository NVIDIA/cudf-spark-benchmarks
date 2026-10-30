WITH  CustomerOrderCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS recent_order
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 100
),
SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
),
OrdersWithDiscount AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.o_orderdate,
    owd.net_revenue,
    sps.s_name,
    sps.total_availability,
    sps.avg_cost
FROM 
    CustomerOrderCTE co
LEFT JOIN 
    OrdersWithDiscount owd ON co.o_orderkey = owd.o_orderkey
LEFT JOIN 
    SupplierPartStats sps ON co.o_orderkey = sps.ps_partkey
WHERE 
    co.recent_order = 1
    AND (sps.total_availability IS NULL OR sps.total_availability > 0)
    AND owd.net_revenue > 5000
ORDER BY 
    co.o_orderdate DESC, 
    co.c_name;
