WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        MAX(o.o_orderdate) AS last_order_date,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name, o.o_orderstatus
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    os.o_orderkey,
    os.c_name,
    os.total_revenue,
    os.unique_parts,
    os.last_order_date,
    os.o_orderstatus,
    ps.supplier_count,
    ps.avg_supply_cost
FROM 
    OrderSummary os
LEFT JOIN 
    PartSupplier ps ON os.o_orderkey = ps.ps_partkey
ORDER BY 
    os.total_revenue DESC
LIMIT 10;