WITH SupplierProfit AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        (SUM(l.l_extendedprice * (1 - l.l_discount)) - SUM(ps.ps_supplycost * ps.ps_availqty)) AS profit
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        AVG(l.l_discount) OVER (PARTITION BY o.o_orderkey) AS avg_discount,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
),
TopSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.profit,
        RANK() OVER (ORDER BY sp.profit DESC) AS profit_rank
    FROM 
        SupplierProfit sp
    WHERE 
        sp.profit > 0
)
SELECT 
    fo.o_orderkey,
    fo.o_totalprice,
    fs.s_name AS supplier_name,
    fs.profit,
    fo.avg_discount,
    fo.order_rank
FROM 
    FilteredOrders fo
LEFT JOIN 
    TopSuppliers fs ON fo.o_custkey = fs.s_suppkey
WHERE 
    fs.profit_rank <= 10 OR fs.profit IS NULL
ORDER BY 
    fo.o_orderkey, fs.profit DESC;