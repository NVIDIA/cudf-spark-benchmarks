WITH RankedLineItems AS (
    SELECT 
        l_orderkey, 
        l_partkey,
        l_suppkey,
        l_quantity,
        l_extendedprice,
        l_discount,
        l_tax,
        DENSE_RANK() OVER (PARTITION BY l_orderkey ORDER BY l_extendedprice DESC) AS rank_price
    FROM 
        lineitem
), TotalOrderValues AS (
    SELECT 
        o_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_value,
        COUNT(DISTINCT l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        RankedLineItems li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey
), SupplierCosts AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)

SELECT 
    n.n_name, 
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    SUM(t.total_value) AS total_order_value,
    AVG(t.total_value) AS avg_order_value,
    SC.total_supply_cost,
    CASE 
        WHEN AVG(t.total_value) > 5000 THEN 'High Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    TotalOrderValues t ON o.o_orderkey = t.o_orderkey
LEFT JOIN 
    SupplierCosts SC ON t.distinct_parts = SC.ps_partkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01'
    AND (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
GROUP BY 
    n.n_name, SC.total_supply_cost
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_order_value DESC;