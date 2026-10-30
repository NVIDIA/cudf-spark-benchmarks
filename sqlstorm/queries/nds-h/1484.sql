WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS number_of_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS number_of_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY si.total_supply_cost DESC) AS rank
    FROM 
        SupplierInfo si
    JOIN 
        supplier s ON si.s_suppkey = s.s_suppkey
    WHERE 
        si.total_supply_cost > (SELECT 
                                    AVG(total_supply_cost) 
                                  FROM 
                                    SupplierInfo)
)
SELECT 
    c.c_custkey,
    c.c_name,
    os.total_price,
    COALESCE(ts.s_name, 'No Supplier') AS supplier_name,
    ts.rank
FROM 
    customer c
LEFT JOIN 
    OrderSummary os ON c.c_custkey = os.o_custkey
LEFT JOIN 
    TopSuppliers ts ON os.number_of_items = ts.rank
WHERE 
    c.c_acctbal > 1000
ORDER BY 
    os.total_price DESC, 
    c.c_name ASC;
