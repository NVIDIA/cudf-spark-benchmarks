WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_availqty DESC) as rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        c.c_custkey, c.c_name
),
RecentLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_returnflag,
        l.l_linestatus,
        LAG(l.l_extendedprice) OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS prev_extendedprice
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '30 days'
)
SELECT 
    sp.s_name,
    sp.p_name,
    sp.ps_availqty,
    COALESCE(co.total_spent, 0) AS total_spent,
    SUM(rl.l_extendedprice) AS total_revenue,
    SUM(CASE 
        WHEN rl.l_returnflag = 'R' THEN rl.l_quantity 
        ELSE 0 
    END) AS returned_quantity
FROM 
    SupplierParts sp
LEFT JOIN 
    RecentLineItems rl ON sp.p_partkey = rl.l_partkey AND sp.s_suppkey = rl.l_suppkey
LEFT JOIN 
    CustomerOrders co ON co.order_count > 10
WHERE 
    sp.rn = 1
GROUP BY 
    sp.s_name, sp.p_name, sp.ps_availqty, co.total_spent
HAVING 
    SUM(rl.l_extendedprice) > 10000 OR COALESCE(co.total_spent, 0) > 5000
ORDER BY 
    total_revenue DESC, sp.ps_availqty ASC;