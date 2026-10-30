WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availability,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ss.total_availability,
        ss.total_cost
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.supplier_rank <= 10
),
LineItemStats AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_extendedprice) AS average_price,
        COUNT(CASE WHEN l.l_discount > 0 THEN 1 END) AS discounted_items,
        COUNT(*) AS total_items,
        RANK() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_quantity) DESC) AS part_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(ts.total_availability, 0) AS supplier_availability,
    COALESCE(ts.total_cost, 0) AS total_cost_to_supplier,
    lis.total_quantity AS total_lineitem_quantity,
    lis.average_price,
    lis.discounted_items,
    lis.total_items
FROM 
    part p
LEFT JOIN 
    TopSuppliers ts ON p.p_partkey = ts.s_suppkey
LEFT JOIN 
    LineItemStats lis ON p.p_partkey = lis.l_partkey
WHERE 
    (p.p_retailprice > 50 OR lis.total_items > 100) 
    AND (ts.s_suppkey IS NOT NULL OR lis.total_quantity < 100)
ORDER BY 
    p.p_partkey ASC, lis.average_price DESC;
