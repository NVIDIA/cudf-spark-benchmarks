WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name = 'GERMANY' AND s.s_acctbal > 10000
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rp.p_name,
    rp.p_brand,
    ts.s_name AS supplier_name,
    od.total_order_value,
    od.unique_parts,
    rp.total_supply_cost,
    rp.supply_rank
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.p_partkey = ts.s_suppkey 
JOIN 
    OrderDetails od ON rp.p_partkey = od.o_orderkey 
WHERE 
    rp.supply_rank <= 5
ORDER BY 
    rp.p_brand, od.total_order_value DESC;