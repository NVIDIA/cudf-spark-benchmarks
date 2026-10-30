
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(DISTINCT l.l_partkey) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_custkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.net_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.net_revenue DESC) AS rank
    FROM 
        customer c
    JOIN 
        OrderDetails o ON c.c_custkey = o.o_custkey
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    COALESCE(su.supplied_parts, 0) AS suppliers_count,
    COALESCE(su.total_cost, 0) AS total_supply_cost,
    cs.o_orderkey AS orderkey,
    cs.net_revenue,
    cs.rank
FROM 
    CustomerOrders cs
LEFT JOIN 
    SupplierSummary su ON cs.c_custkey = (
        SELECT 
            c.c_custkey 
        FROM 
            customer c 
        WHERE 
            c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'GERMANY')
        LIMIT 1
    )
WHERE 
    cs.rank <= 3
ORDER BY 
    cs.c_custkey, cs.net_revenue DESC;
