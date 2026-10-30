WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
),
TopOrders AS (
    SELECT * 
    FROM RankedOrders 
    WHERE order_rank <= 10
),
SupplierDetails AS (
    SELECT 
        ps.ps_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        TopOrders t ON l.l_orderkey = t.o_orderkey
    GROUP BY 
        ps.ps_suppkey, s.s_name
)
SELECT 
    r.r_name AS region_name,
    nd.n_name AS nation_name,
    sd.s_name AS supplier_name,
    sd.total_supply_cost
FROM 
    SupplierDetails sd
JOIN 
    supplier s ON sd.ps_suppkey = s.s_suppkey
JOIN 
    nation nd ON s.s_nationkey = nd.n_nationkey
JOIN 
    region r ON nd.n_regionkey = r.r_regionkey
ORDER BY 
    total_supply_cost DESC
LIMIT 20;
