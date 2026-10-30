
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey, 
        ss.s_name,
        ss.total_avail_qty,
        ss.avg_supply_cost,
        RANK() OVER (ORDER BY ss.total_avail_qty DESC) AS supplier_rank
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_avail_qty IS NOT NULL
)
SELECT 
    ts.s_name,
    ts.total_avail_qty,
    ts.avg_supply_cost,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Orders' 
        ELSE 'Has Orders' 
    END AS order_status,
    os.total_revenue
FROM 
    TopSuppliers ts
LEFT JOIN 
    OrderStats os ON ts.s_suppkey = (SELECT ps.ps_suppkey 
                                       FROM partsupp ps 
                                       WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                               FROM part p 
                                                               WHERE p.p_brand LIKE 'Brand#%') 
                                       LIMIT 1) 
WHERE 
    ts.supplier_rank <= 10
ORDER BY 
    ts.total_avail_qty DESC, ts.avg_supply_cost ASC;
