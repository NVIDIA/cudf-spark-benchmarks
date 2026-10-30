
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
OrderSupplierDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    h.o_orderkey,
    h.c_name,
    h.total_price,
    os.total_supply_cost,
    os.num_suppliers,
    CASE 
        WHEN s.supplier_rank IS NOT NULL THEN s.supplier_rank
        ELSE 0 
    END AS supplier_rank
FROM 
    HighValueOrders h
LEFT JOIN 
    OrderSupplierDetails os ON h.o_orderkey = os.o_orderkey
LEFT JOIN 
    RankedSuppliers s ON h.o_orderkey = s.s_suppkey
WHERE 
    (h.total_price - COALESCE(os.total_supply_cost, 0)) > 10000
ORDER BY 
    h.total_price DESC
LIMIT 100;
