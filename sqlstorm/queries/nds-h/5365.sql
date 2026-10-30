WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        l.l_tax
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
),
AggregateSupplierData AS (
    SELECT 
        spd.s_suppkey,
        spd.s_name,
        SUM(spd.ps_supplycost * cod.l_quantity) AS total_supply_cost
    FROM 
        SupplierPartDetails spd
    JOIN 
        CustomerOrders cod ON spd.ps_partkey = cod.l_partkey
    GROUP BY 
        spd.s_suppkey, spd.s_name
)
SELECT 
    asd.s_name,
    asd.total_supply_cost,
    n.n_name AS supplier_nation,
    r.r_name AS supplier_region,
    COUNT(DISTINCT co.o_orderkey) AS total_orders
FROM 
    AggregateSupplierData asd
JOIN 
    supplier s ON asd.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    orders co ON s.s_suppkey = co.o_custkey
GROUP BY 
    asd.s_name, asd.total_supply_cost, n.n_name, r.r_name
ORDER BY 
    total_supply_cost DESC, asd.s_name ASC
LIMIT 100;
