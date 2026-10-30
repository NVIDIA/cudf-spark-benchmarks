WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
FrequentCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        l.l_suppkey, 
        l.l_quantity, 
        l.l_extendedprice, 
        l.l_discount, 
        l.l_tax
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
        AND l.l_returnflag = 'N'
)
SELECT 
    fs.c_name AS customer_name, 
    rs.s_name AS supplier_name, 
    SUM(fli.l_extendedprice) AS total_revenue,
    COUNT(DISTINCT fli.l_orderkey) AS total_orders,
    ROW_NUMBER() OVER (ORDER BY SUM(fli.l_extendedprice) DESC) AS revenue_rank
FROM 
    FrequentCustomers fs
JOIN 
    orders o ON fs.c_custkey = o.o_custkey
JOIN 
    FilteredLineItems fli ON o.o_orderkey = fli.l_orderkey
JOIN 
    RankedSuppliers rs ON fli.l_suppkey = rs.s_suppkey
WHERE 
    rs.rank <= 10
GROUP BY 
    fs.c_name, rs.s_name
ORDER BY 
    total_revenue DESC;