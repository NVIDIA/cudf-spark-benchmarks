WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_mktsegment = 'BUILDING' 
    GROUP BY 
        c.c_custkey, c.c_name
), 
DateRangeSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales,
        l.l_returnflag,
        l.l_linestatus
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        l.l_orderkey, l.l_returnflag, l.l_linestatus
)
SELECT 
    c.c_name,
    co.order_count,
    co.total_spent,
    SUM(dr.sales) AS total_sales,
    COALESCE(ts.total_supply_cost, 0) AS top_supplier_cost,
    RANK() OVER (ORDER BY SUM(dr.sales) DESC) AS sales_rank
FROM 
    CustomerOrders co
JOIN 
    CustomerOrders c ON co.c_custkey = c.c_custkey
LEFT JOIN 
    DateRangeSales dr ON dr.l_orderkey = co.c_custkey
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey = (SELECT ps.ps_suppkey 
                                        FROM partsupp ps 
                                        ORDER BY ps.ps_supplycost DESC 
                                        LIMIT 1)
WHERE 
    co.total_spent IS NOT NULL
GROUP BY 
    c.c_name, co.order_count, co.total_spent, ts.total_supply_cost
ORDER BY 
    sales_rank;