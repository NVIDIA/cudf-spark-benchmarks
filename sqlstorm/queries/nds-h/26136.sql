
WITH SupplierDetails AS (
    SELECT 
        s.s_name AS supplier_name, 
        s.s_address AS supplier_address, 
        CONCAT(n.n_name, ', ', r.r_name) AS location, 
        s.s_acctbal AS account_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartsStatistics AS (
    SELECT 
        p.p_name AS part_name, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
        AVG(ps.ps_supplycost) AS average_supply_cost, 
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    sd.supplier_name,
    sd.supplier_address,
    sd.location,
    sd.account_balance,
    ps.part_name,
    ps.supplier_count,
    ps.average_supply_cost,
    ps.total_available_quantity,
    od.o_orderkey,
    od.o_orderdate,
    od.total_revenue
FROM 
    SupplierDetails sd
JOIN 
    PartsStatistics ps ON sd.account_balance > 10000
JOIN 
    OrderDetails od ON od.total_revenue > 5000
WHERE 
    sd.location LIKE '%North America%'
ORDER BY 
    ps.supplier_count DESC, 
    od.total_revenue DESC;
