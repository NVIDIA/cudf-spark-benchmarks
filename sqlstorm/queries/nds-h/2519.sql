
WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS total_lines,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, c.c_custkey
),
SupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        SUM(os.total_revenue) AS customer_revenue
    FROM 
        OrderSummary os
    JOIN 
        customer c ON os.c_custkey = c.c_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(os.total_revenue) > 10000
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_cost,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        SupplierSummary ss ON s.s_suppkey = ss.ps_partkey
)

SELECT 
    rc.c_custkey,
    rc.customer_revenue,
    rs.s_suppkey,
    rs.s_name,
    rs.total_supply_cost,
    rs.supplier_rank
FROM 
    TopCustomers rc
LEFT JOIN 
    RankedSuppliers rs ON rc.c_custkey = rs.s_suppkey
WHERE 
    rs.supplier_rank <= 10 OR rs.supplier_rank IS NULL
ORDER BY 
    rc.customer_revenue DESC, 
    rs.total_supply_cost ASC
