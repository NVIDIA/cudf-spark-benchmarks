
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT li.l_linenumber) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RankedOrders AS (
    SELECT 
        od.o_orderkey,
        od.o_orderdate,
        od.total_revenue,
        od.total_line_items,
        RANK() OVER (ORDER BY od.total_revenue DESC) AS revenue_rank
    FROM 
        OrderDetails od
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_avail_qty,
        ss.avg_supply_cost,
        ss.total_parts,
        RANK() OVER (ORDER BY ss.total_avail_qty DESC, ss.avg_supply_cost ASC) AS supplier_rank
    FROM 
        SupplierStats ss
)
SELECT 
    ts.s_name,
    ts.total_avail_qty,
    ts.avg_supply_cost,
    CAST(ro.o_orderdate AS VARCHAR(10)) AS order_date,
    ro.total_revenue
FROM 
    TopSuppliers ts
LEFT JOIN 
    RankedOrders ro ON ts.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#36'))
WHERE 
    ts.supplier_rank <= 5 AND
    (ro.total_revenue IS NOT NULL OR ts.total_parts > 10)
ORDER BY 
    ts.total_avail_qty DESC, 
    ro.total_revenue DESC NULLS LAST;
