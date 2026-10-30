WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
)
SELECT 
    rs.o_orderkey,
    rs.o_orderdate,
    CAST(SUM(li.l_extendedprice * (1 - li.l_discount)) AS DECIMAL(12, 2)) AS net_revenue,
    ss.total_parts,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        ELSE 'Orders Placed'
    END AS order_status
FROM 
    RankedOrders rs
LEFT JOIN 
    lineitem li ON rs.o_orderkey = li.l_orderkey
LEFT JOIN 
    SupplierSummary ss ON li.l_suppkey = ss.s_suppkey
LEFT JOIN 
    CustomerOrders cs ON rs.o_orderkey = cs.c_custkey
WHERE 
    li.l_returnflag = 'N'
GROUP BY 
    rs.o_orderkey, rs.o_orderdate, ss.total_parts, cs.total_spent
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 1000.00
ORDER BY 
    rs.o_orderdate DESC, net_revenue DESC;