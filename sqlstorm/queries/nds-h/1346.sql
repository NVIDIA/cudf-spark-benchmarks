WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
    HAVING 
        SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) IS NOT NULL
)
SELECT 
    ns.n_name AS nation_name,
    COUNT(DISTINCT rv.s_suppkey) AS supplier_count,
    COUNT(DISTINCT hvo.o_orderkey) AS high_value_orders,
    SUM(pd.total_cost) AS total_supplier_cost
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    RankedSuppliers rv ON ns.n_nationkey = rv.s_suppkey
LEFT JOIN 
    HighValueOrders hvo ON hvo.o_orderkey = rv.s_suppkey
LEFT JOIN 
    PartSupplierDetails pd ON rv.s_suppkey = pd.ps_partkey
WHERE 
    ns.n_name IS NOT NULL
GROUP BY 
    ns.n_name
ORDER BY 
    total_supplier_cost DESC
LIMIT 10;
