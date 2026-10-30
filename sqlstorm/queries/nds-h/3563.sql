WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate, 
        o.o_orderstatus, 
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    INNER JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 5000
    GROUP BY 
        ps.ps_partkey, 
        ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, 
        c.c_name
)
SELECT 
    co.c_name,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        ELSE CAST(co.total_spent AS STRING) 
    END AS total_orders,
    sp.total_available_quantity,
    sp.average_supply_cost,
    r.r_name
FROM 
    CustomerOrders co
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey IN (
        SELECT 
            l.l_partkey 
        FROM 
            lineitem l
        WHERE 
            l.l_orderkey IN (
                SELECT 
                    o.o_orderkey 
                FROM 
                    RankedOrders o
                WHERE 
                    o.order_rank <= 10
            )
    )
LEFT JOIN 
    nation n ON co.c_custkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    (sp.total_available_quantity IS NULL OR sp.average_supply_cost < 500)
    AND r.r_name IS NOT NULL
ORDER BY 
    co.c_name;