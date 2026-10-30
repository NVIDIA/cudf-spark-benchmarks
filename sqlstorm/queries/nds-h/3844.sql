WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
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
        ss.total_cost, 
        ss.parts_supplied,
        ROW_NUMBER() OVER (ORDER BY ss.total_cost DESC) AS rank
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_cost > 10000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ts.s_name AS supplier_name,
    os.o_orderkey AS order_number,
    os.total_order_value,
    os.item_count,
    CASE 
        WHEN os.item_count > 5 THEN 'Bulk Order'
        WHEN os.item_count IS NULL THEN 'No Items'
        ELSE 'Regular Order'
    END AS order_type,
    COALESCE(n.n_name, 'Unknown') AS nation_name
FROM 
    TopSuppliers ts
LEFT JOIN 
    OrderSummary os ON ts.s_suppkey = os.o_orderkey 
LEFT JOIN 
    supplier s ON ts.s_suppkey = s.s_suppkey 
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    ts.rank <= 10
ORDER BY 
    ts.total_cost DESC, os.o_orderkey;