WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        si.s_suppkey, 
        si.s_name,
        si.total_supply_cost
    FROM 
        SupplierInfo si
    WHERE 
        si.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierInfo)
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    COALESCE(t.s_name, 'No Supplier') AS supplier_name,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT l.l_suppkey) AS unique_suppliers_count
FROM 
    RankedOrders o
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    TopSuppliers t ON l.l_suppkey = t.s_suppkey
WHERE 
    o.rank_order <= 10
GROUP BY 
    o.o_orderkey, o.o_orderdate, o.o_totalprice, t.s_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    o.o_orderdate DESC, o.o_totalprice ASC;